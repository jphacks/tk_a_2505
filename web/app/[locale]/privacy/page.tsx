import { getTranslations, setRequestLocale } from "next-intl/server";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Shield,
  Database,
  Eye,
  Lock,
  UserCheck,
  TriangleAlert,
  Mail,
  Calendar,
  Music,
} from "lucide-react";

type Props = {
  params: Promise<{ locale: string }>;
};

export default async function PrivacyPolicy({ params }: Props) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("privacy");

  const privacySections = [
    {
      icon: Database,
      title: t("infoCollectTitle"),
      items: [
        t("infoCollect1"),
        t("infoCollect2"),
        t("infoCollect3"),
        t("infoCollect4"),
      ],
    },
    {
      icon: Eye,
      title: t("howWeUseTitle"),
      items: [t("howWeUse1"), t("howWeUse2"), t("howWeUse3"), t("howWeUse4")],
    },
    {
      icon: Shield,
      title: t("infoSharingTitle"),
      items: [
        t("infoSharing1"),
        t("infoSharing2"),
        t("infoSharing3"),
        t("infoSharing4"),
      ],
    },
    {
      icon: Music,
      title: t("locationDataTitle"),
      items: [
        t("locationData1"),
        t("locationData2"),
        t("locationData3"),
        t("locationData4"),
      ],
    },
    {
      icon: Lock,
      title: t("dataSecurityTitle"),
      items: [
        t("dataSecurity1"),
        t("dataSecurity2"),
        t("dataSecurity3"),
        t("dataSecurity4"),
      ],
    },
    {
      icon: UserCheck,
      title: t("yourRightsTitle"),
      items: [
        t("yourRights1"),
        t("yourRights2"),
        t("yourRights3"),
        t("yourRights4"),
      ],
    },
    {
      icon: TriangleAlert,
      title: t("dataRetentionTitle"),
      items: [
        t("dataRetention1"),
        t("dataRetention2"),
        t("dataRetention3"),
        t("dataRetention4"),
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

        {/* Our Commitment */}
        <Card className="mb-8">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Shield className="h-5 w-5" />
              {t("commitmentTitle")}
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4 text-zinc-600 dark:text-zinc-400">
            <p>{t("commitmentPara1")}</p>
            <p>{t("commitmentPara2")}</p>
          </CardContent>
        </Card>

        {/* Grid of Cards */}
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          {privacySections.map((section, index) => {
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

        {/* Changes to Policy */}
        <div className="mt-8">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <TriangleAlert className="h-5 w-5" />
                {t("changesToPolicyTitle")}
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4 text-zinc-600 dark:text-zinc-400">
              <p>{t("changesToPolicyPara1")}</p>
              <p>{t("changesToPolicyPara2")}</p>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
