import { getTranslations, setRequestLocale } from "next-intl/server";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Shield,
  FileText,
  AlertCircle,
  Ban,
  Scale,
  UserX,
  Mail,
  Calendar,
  Gavel,
} from "lucide-react";

type Props = {
  params: Promise<{ locale: string }>;
};

export default async function TermsOfService({ params }: Props) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("tos");

  const tosSections = [
    {
      icon: FileText,
      title: t("useLicenseTitle"),
      items: [
        t("useLicense1"),
        t("useLicense2"),
        t("useLicense3"),
        t("useLicense4"),
      ],
    },
    {
      icon: AlertCircle,
      title: t("userObligationsTitle"),
      items: [
        t("userObligations1"),
        t("userObligations2"),
        t("userObligations3"),
        t("userObligations4"),
      ],
    },
    {
      icon: Ban,
      title: t("prohibitedUsesTitle"),
      items: [
        t("prohibitedUses1"),
        t("prohibitedUses2"),
        t("prohibitedUses3"),
        t("prohibitedUses4"),
        t("prohibitedUses5"),
      ],
    },
    {
      icon: AlertCircle,
      title: t("serviceAvailabilityTitle"),
      items: [
        t("serviceAvailability1"),
        t("serviceAvailability2"),
        t("serviceAvailability3"),
        t("serviceAvailability4"),
      ],
    },
    {
      icon: Scale,
      title: t("limitationLiabilityTitle"),
      items: [
        t("limitationLiability1"),
        t("limitationLiability2"),
        t("limitationLiability3"),
        t("limitationLiability4"),
      ],
    },
    {
      icon: UserX,
      title: t("accountTerminationTitle"),
      items: [
        t("accountTermination1"),
        t("accountTermination2"),
        t("accountTermination3"),
        t("accountTermination4"),
      ],
    },
    {
      icon: Shield,
      title: t("intellectualPropertyTitle"),
      items: [
        t("intellectualProperty1"),
        t("intellectualProperty2"),
        t("intellectualProperty3"),
        t("intellectualProperty4"),
      ],
    },
    {
      icon: Gavel,
      title: t("thirdPartyServicesTitle"),
      items: [
        t("thirdPartyServices1"),
        t("thirdPartyServices2"),
        t("thirdPartyServices3"),
        t("thirdPartyServices4"),
      ],
    },
  ];

  return (
    <div className="min-h-screen bg-zinc-50 pt-20 dark:bg-zinc-950">
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <div className="mb-12 text-center">
          <h1 className="mb-4 text-4xl font-bold text-zinc-900 dark:text-white">
            {t("title")}
          </h1>
          <p className="mb-6 text-xl text-zinc-600 dark:text-zinc-400">
            {t("subtitle")}
          </p>
          <div className="flex items-center justify-center gap-4">
            <Badge variant="secondary">
              <Calendar className="mr-1 h-3 w-3" />
              {t("lastUpdated")}
            </Badge>
          </div>
        </div>

        {/* Agreement to Terms */}
        <Card className="mb-8">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Shield className="h-5 w-5" />
              {t("agreementTitle")}
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4 text-zinc-600 dark:text-zinc-400">
            <p>{t("agreementPara1")}</p>
            <p>{t("agreementPara2")}</p>
          </CardContent>
        </Card>

        {/* Grid of Cards */}
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          {tosSections.map((section, index) => {
            const Icon = section.icon;
            return (
              <Card key={index} className="h-full">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Icon className="h-6 w-6" />
                    {section.title}
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <ul className="space-y-2 text-zinc-600 dark:text-zinc-400">
                    {section.items.map((item, itemIndex) => (
                      <li key={itemIndex} className="flex items-start gap-2">
                        <div className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full bg-zinc-400" />
                        {item}
                      </li>
                    ))}
                  </ul>
                </CardContent>
              </Card>
            );
          })}
        </div>

        {/* Governing Law */}
        <div className="mt-8">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Scale className="h-5 w-5" />
                {t("governingLawTitle")}
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4 text-zinc-600 dark:text-zinc-400">
              <p>{t("governingLawPara1")}</p>
              <p>{t("governingLawPara2")}</p>
            </CardContent>
          </Card>
        </div>

        {/* Contact Us */}
        <div className="mt-8">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Mail className="h-5 w-5" />
                {t("contactUsTitle")}
              </CardTitle>
              <p className="text-sm text-zinc-600 dark:text-zinc-400">
                {t("contactUsSubtitle")}
              </p>
            </CardHeader>
            <CardContent className="space-y-4 text-zinc-600 dark:text-zinc-400">
              <p>{t("contactUsPara")}</p>
              <div className="rounded-lg border bg-zinc-50 p-4 dark:bg-zinc-900">
                <div className="space-y-2">
                  <p>
                    <strong>{t("contactEmail")}</strong>{" "}
                    <a
                      href="mailto:jphacks2505@gmail.com"
                      className="hover:underline"
                    >
                      jphacks2505@gmail.com
                    </a>
                  </p>
                  <p>
                    <strong>{t("contactResponseTime")}</strong>
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Changes to Terms */}
        <div className="mt-8">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <AlertCircle className="h-5 w-5" />
                {t("changesToTermsTitle")}
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4 text-zinc-600 dark:text-zinc-400">
              <p>{t("changesToTermsPara1")}</p>
              <p>{t("changesToTermsPara2")}</p>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
